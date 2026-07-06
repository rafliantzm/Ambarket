import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/order/presentation/screens/order_tracking_screen.dart';
import 'package:ambarket_mobile/features/order/domain/models/order_model.dart';
import 'package:ambarket_mobile/features/order/presentation/providers/order_provider.dart';

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
          buyerOrdersProvider.overrideWith((ref) => [mockOrder]), // synchronous return!
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
  });
}
