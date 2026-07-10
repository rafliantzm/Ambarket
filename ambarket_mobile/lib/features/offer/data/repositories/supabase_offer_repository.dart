import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/offer_model.dart';
import '../../../../features/order/domain/models/order_model.dart';
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
        .select(
          '*, products(id, title, product_images(id, image_url, is_primary)), buyer:profiles!buyer_id(id, name, avatar_url), seller:profiles!seller_id(id, name, avatar_url)',
        )
        .single();

    return OfferModel.fromJson(response);
  }

  @override
  Future<List<OfferModel>> fetchMySentOffers(String buyerId) async {
    final response = await _client
        .from('offers')
        .select(
          '*, products(id, title, product_images(id, image_url, is_primary)), seller:profiles!seller_id(id, name, avatar_url)',
        )
        .eq('buyer_id', buyerId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => OfferModel.fromJson(json)).toList();
  }

  @override
  Future<List<OfferModel>> fetchMyReceivedOffers(String sellerId) async {
    return fetchReceivedOffersFiltered(sellerId);
  }

  @override
  Future<List<OfferModel>> fetchReceivedOffersFiltered(
    String sellerId, {
    String? status,
  }) async {
    var query = _client
        .from('offers')
        .select(
          '*, products(id, title, product_images(id, image_url, is_primary)), buyer:profiles!buyer_id(id, name, avatar_url)',
        )
        .eq('seller_id', sellerId);

    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List).map((json) => OfferModel.fromJson(json)).toList();
  }

  @override
  Future<OrderModel?> findOrderByOfferId(String offerId) async {
    final response = await _client
        .from('orders')
        .select(
          '*, product:products(id, title, product_images(id, image_url, is_primary)), buyer:profiles!orders_buyer_id_fkey(id, name, avatar_url), seller:profiles!orders_seller_id_fkey(id, name, avatar_url)',
        )
        .eq('offer_id', offerId)
        .maybeSingle();

    if (response == null) return null;
    return OrderModel.fromJson(response);
  }

  @override
  Future<List<OfferModel>> fetchOffersForProduct(String productId) async {
    final response = await _client
        .from('offers')
        .select('*, buyer:profiles!buyer_id(id, name, avatar_url)')
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
        .update({
          'status': 'accepted',
          'accepted_at': DateTime.now().toIso8601String(),
          'expires_at': DateTime.now()
              .add(const Duration(hours: 12))
              .toIso8601String(),
        })
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

  @override
  Future<OfferModel?> fetchValidAcceptedOffer(
    String productId,
    String buyerId,
  ) async {
    final response = await _client
        .from('offers')
        .select(
          '*, products(*, product_images(*)), buyer:profiles!buyer_id(*), seller:profiles!seller_id(*)',
        )
        .eq('product_id', productId)
        .eq('buyer_id', buyerId)
        .eq('status', 'accepted')
        .gt('expires_at', DateTime.now().toIso8601String())
        .order('created_at', ascending: false)
        .maybeSingle();

    if (response == null) return null;
    return OfferModel.fromJson(response);
  }
}
