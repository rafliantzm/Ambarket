import 'package:ambarket_mobile/features/order/domain/models/order_model.dart';

abstract class OrderRepository {
  /// Create a new order
  Future<OrderModel> createOrder({
    required String productId,
    required String buyerId,
    required String sellerId,
    required double totalPrice,
    required String shippingAddress,
    required String shippingPhone,
    String? offerId,
  });

  /// Fetch orders placed by the current user
  Future<List<OrderModel>> fetchBuyerOrders(String buyerId);

  /// Fetch orders received by the current user (as seller)
  Future<List<OrderModel>> fetchSellerOrders(String sellerId);

  /// Update the status of an order
  Future<void> updateOrderStatus(String orderId, String newStatus);
}
