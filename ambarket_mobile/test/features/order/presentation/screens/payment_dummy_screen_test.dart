import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/order/presentation/screens/payment_dummy_screen.dart';
import 'package:ambarket_mobile/features/order/domain/models/order_model.dart';
import 'package:ambarket_mobile/features/order/presentation/providers/order_provider.dart';

void main() {
  testWidgets('PaymentDummyScreen renders payment instruction', (WidgetTester tester) async {
    final mockOrder = OrderModel(
      id: 'order_uuid',
      productId: 'p1',
      buyerId: 'b1',
      sellerId: 's1',
      totalPrice: 150000,
      subtotal: 150000,
      shippingAddress: 'Address',
      receiverPhone: '0800',
      status: 'pending_payment',
      paymentMethod: 'bca',
      paymentStatus: 'unpaid',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      invoiceNumber: 'INV/2026/01/01/1',
    );

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          buyerOrdersProvider.overrideWith((ref) => [mockOrder]),
          sellerOrdersProvider.overrideWith((ref) => []),
        ],
        child: const MaterialApp(
          home: PaymentDummyScreen(orderId: 'order_uuid'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pembayaran'), findsOneWidget);
    expect(find.text('Instruksi Pembayaran Dummy:'), findsOneWidget);
    expect(find.text('Saya Sudah Bayar'), findsOneWidget);
  });
}
