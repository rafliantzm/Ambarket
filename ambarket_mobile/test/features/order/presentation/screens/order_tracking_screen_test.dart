import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/order/presentation/screens/order_tracking_screen.dart';
import 'package:ambarket_mobile/features/order/domain/models/order_model.dart';
import 'package:ambarket_mobile/features/order/domain/models/refund_request_model.dart';
import 'package:ambarket_mobile/features/order/domain/repositories/order_repository.dart';
import 'package:ambarket_mobile/features/order/presentation/providers/order_provider.dart';
import 'package:ambarket_mobile/features/notification/domain/models/notification_model.dart';
import 'package:ambarket_mobile/features/notification/domain/repositories/notification_repository.dart';
import 'package:ambarket_mobile/features/notification/presentation/providers/notification_provider.dart';

void main() {
  testWidgets('OrderTrackingScreen renders steps', (WidgetTester tester) async {
    final mockOrder = OrderModel(
      id: 'order_uuid',
      productId: 'p1',
      buyerId: 'b1',
      sellerId: 's1',
      totalPrice: 150000,
      subtotal: 150000,
      shippingAddress: 'Address',
      receiverPhone: '0800',
      status: 'shipped',
      paymentMethod: 'bca',
      paymentStatus: 'paid',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      invoiceNumber: 'INV/2026/01/01/TEST',
    );

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          buyerOrdersProvider.overrideWith(
            (ref) => [mockOrder],
          ), // synchronous return!
          sellerOrdersProvider.overrideWith((ref) => []),
        ],
        child: const MaterialApp(
          home: OrderTrackingScreen(orderId: 'order_uuid'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Lacak Pesanan'), findsOneWidget);
    expect(find.text('Pesanan Dibuat'), findsOneWidget);
    expect(find.text('Pembayaran Diterima'), findsOneWidget);
    expect(find.text('Barang Dikirim'), findsOneWidget);
    expect(find.text('Pesanan Diterima'), findsOneWidget);
  });

  testWidgets('OrderTrackingScreen marks shipped order as delivered', (
    WidgetTester tester,
  ) async {
    final mockOrder = OrderModel(
      id: 'order_uuid',
      productId: 'p1',
      buyerId: 'b1',
      sellerId: 's1',
      totalPrice: 150000,
      subtotal: 150000,
      shippingAddress: 'Address',
      receiverPhone: '0800',
      status: 'shipped',
      paymentMethod: 'bca',
      paymentStatus: 'paid',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      invoiceNumber: 'INV/2026/01/01/TEST',
    );
    final fakeOrderRepository = _FakeOrderRepository();

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          buyerOrdersProvider.overrideWith((ref) => [mockOrder]),
          sellerOrdersProvider.overrideWith((ref) => []),
          orderRepositoryProvider.overrideWithValue(fakeOrderRepository),
          notificationRepositoryProvider.overrideWithValue(
            _FakeNotificationRepository(),
          ),
        ],
        child: const MaterialApp(
          home: OrderTrackingScreen(orderId: 'order_uuid'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Pesanan Diterima'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, Terima'));
    await tester.pumpAndSettle();

    expect(fakeOrderRepository.updatedOrderId, 'order_uuid');
    expect(fakeOrderRepository.updatedStatus, 'delivered');
  });
}

class _FakeOrderRepository implements OrderRepository {
  String? updatedOrderId;
  String? updatedStatus;

  @override
  Future<void> cancelSellerOrder(String orderId, String sellerId) async {}

  @override
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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<OrderModel>> fetchBuyerOrders(String buyerId) async => [];

  @override
  Future<List<OrderModel>> fetchSellerOrders(String sellerId) async => [];

  @override
  Future<List<OrderModel>> fetchSellerOrdersFiltered(
    String sellerId, {
    String? status,
    String? paymentStatus,
  }) async => [];

  @override
  Future<void> simulatePayment(String orderId) async {}

  @override
  Future<RefundRequestModel> requestRefund({
    required String orderId,
    required String reason,
    required String description,
    required double requestedAmount,
    List<String> evidenceUrls = const [],
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    updatedOrderId = orderId;
    updatedStatus = newStatus;
  }
}

class _FakeNotificationRepository implements NotificationRepository {
  @override
  Future<void> createDummyNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? relatedType,
    String? relatedId,
  }) async {}

  @override
  Future<List<NotificationModel>> fetchNotifications() async => [];

  @override
  Future<int> fetchUnreadCount() async => 0;

  @override
  Future<void> markAllAsRead() async {}

  @override
  Future<void> markAsRead(String id) async {}
}
