import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ambarket_mobile/features/order/domain/models/order_model.dart';
import 'package:ambarket_mobile/features/order/domain/repositories/order_repository.dart';

class SupabaseOrderRepository implements OrderRepository {
  final SupabaseClient _client;

  SupabaseOrderRepository(this._client);

  @override
  Future<OrderModel> createOrder({
    required String productId,
    required String buyerId,
    required String sellerId,
    required double totalPrice,
    required String shippingAddress,
    required String shippingPhone,
    String? offerId,
  }) async {
    try {
      final response = await _client.from('orders').insert({
        'product_id': productId,
        'buyer_id': buyerId,
        'seller_id': sellerId,
        'total_price': totalPrice,
        'shipping_address': shippingAddress,
        'shipping_phone': shippingPhone,
        'offer_id': offerId,
      }).select().single();

      return OrderModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('Pesanan untuk penawaran ini sudah dibuat.');
      }
      rethrow;
    }
  }

  @override
  Future<List<OrderModel>> fetchBuyerOrders(String buyerId) async {
    final response = await _client
        .from('orders')
        .select('*, product:products(*, category:categories(*), images:product_images(*)), seller:profiles!orders_seller_id_fkey(*), reviews(id)')
        .eq('buyer_id', buyerId)
        .order('created_at', ascending: false);

    return response.map((json) => OrderModel.fromJson(json)).toList();
  }

  @override
  Future<List<OrderModel>> fetchSellerOrders(String sellerId) async {
    final response = await _client
        .from('orders')
        .select('*, product:products(*, category:categories(*), images:product_images(*)), buyer:profiles!orders_buyer_id_fkey(*), reviews(id)')
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);

    return response.map((json) => OrderModel.fromJson(json)).toList();
  }

  @override
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _client
        .from('orders')
        .update({'status': newStatus})
        .eq('id', orderId);
  }
}
