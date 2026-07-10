import 'package:ambarket_mobile/features/order/domain/models/order_model.dart';

abstract class OrderRepository {
  /// Create a new order
  Future<OrderModel> createOrder({
    required String productId,
    required String buyerId,
    required String sellerId,
    required double totalPrice,

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
  });

  /// Fetch orders placed by the current user
  Future<List<OrderModel>> fetchBuyerOrders(String buyerId);

  /// Fetch orders received by the current user (as seller)
  Future<List<OrderModel>> fetchSellerOrders(String sellerId);

  /// Fetch orders received by the current user with filters
  Future<List<OrderModel>> fetchSellerOrdersFiltered(
    String sellerId, {
    String? status,
    String? paymentStatus,
  });

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus);

  /// Cancel order by seller (with strict validation)
  Future<void> cancelSellerOrder(String orderId, String sellerId);

  /// Simulate payment for an order
  Future<void> simulatePayment(String orderId);
}
