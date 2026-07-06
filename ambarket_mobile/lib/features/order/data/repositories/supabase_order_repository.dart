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
    required double totalPrice, // fallback
    
    required String receiverName,
    required String receiverPhone,
    required String shippingAddress,
    required String shippingMethod,
    required double shippingCost,
    required String paymentMethod,
    String? voucherCode,
    required double discountAmount,
    required double serviceFee,
    required double subtotal,
    String? offerId,
  }) async {
    try {
      final response = await _client.from('orders').insert({
        'product_id': productId,
        'buyer_id': buyerId,
        'seller_id': sellerId,
        'total_price': subtotal, // map new subtotal to total_price for legacy reasons
        'receiver_name': receiverName,
        'receiver_phone': receiverPhone,
        'shipping_address': shippingAddress,
        'shipping_phone': receiverPhone,
        'shipping_method': shippingMethod,
        'shipping_cost': shippingCost,
        'payment_method': paymentMethod,
        'voucher_code': voucherCode,
        'discount_amount': discountAmount,
        'service_fee': serviceFee,
        'subtotal': subtotal,
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
    return fetchSellerOrdersFiltered(sellerId);
  }

  @override
  Future<List<OrderModel>> fetchSellerOrdersFiltered(String sellerId, {String? status, String? paymentStatus}) async {
    var query = _client
        .from('orders')
        .select('*, product:products(*, category:categories(*), images:product_images(*)), buyer:profiles!orders_buyer_id_fkey(*), reviews(id)')
        .eq('seller_id', sellerId);

    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }

    if (paymentStatus != null && paymentStatus != 'all') {
      if (paymentStatus == 'cod') {
        query = query.eq('payment_method', 'cod');
      } else {
        query = query.eq('payment_status', paymentStatus);
      }
    }

    final response = await query.order('created_at', ascending: false);

    return response.map((json) => OrderModel.fromJson(json)).toList();
  }

  @override
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _client.from('orders').update({'status': newStatus}).eq('id', orderId);
  }

  @override
  Future<void> cancelSellerOrder(String orderId, String sellerId) async {
    final response = await _client.from('orders').select('status').eq('id', orderId).eq('seller_id', sellerId).single();
    final status = response['status'] as String;

    if (status == 'pending_payment' || status == 'paid') {
      await _client.from('orders').update({'status': 'cancelled'}).eq('id', orderId);
    } else {
      throw Exception('Pesanan tidak dapat dibatalkan pada tahap ini.');
    }
  }

  @override
  Future<void> simulatePayment(String orderId) async {
    await _client.from('orders').update({
      'payment_status': 'paid',
      'status': 'paid',
      'paid_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', orderId);
  }
}
