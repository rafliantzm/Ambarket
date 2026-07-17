import 'package:ambarket_mobile/features/order/domain/models/order_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderModel.fromJson', () {
    test('parses paid legacy rows with missing optional fields safely', () {
      final order = OrderModel.fromJson({
        'id': 'order-1',
        'product_id': 'product-1',
        'buyer_id': 'buyer-1',
        'seller_id': 'seller-1',
        'total_price': 15000,
        'status': 'paid',
        'payment_status': 'paid',
        'payment_method': null,
        'paid_at': '2026-07-12T12:00:00.000Z',
        'created_at': null,
        'updated_at': null,
        'product': {'id': 'product-1', 'title': null},
        'seller': {'id': 'seller-1', 'name': 'Penjual', 'created_at': null},
        'reviews': null,
      });

      expect(order.id, 'order-1');
      expect(order.totalPrice, 15000);
      expect(order.subtotal, 15000);
      expect(order.status, 'paid');
      expect(order.paymentStatus, 'paid');
      expect(order.paymentMethod, 'cod');
      expect(order.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
      expect(order.updatedAt, DateTime.fromMillisecondsSinceEpoch(0));
      expect(order.product?.title, 'Produk');
      expect(order.seller?.name, 'Penjual');
      expect(order.isReviewed, isFalse);
    });

    test('falls back instead of throwing when core strings are null', () {
      final order = OrderModel.fromJson({
        'id': null,
        'product_id': null,
        'buyer_id': null,
        'seller_id': null,
        'total_price': null,
        'status': null,
        'created_at': 'invalid-date',
      });

      expect(order.id, 'unknown-order');
      expect(order.productId, '');
      expect(order.buyerId, '');
      expect(order.sellerId, '');
      expect(order.totalPrice, 0);
      expect(order.status, 'pending_payment');
    });
  });
}
