import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/order/presentation/screens/invoice_screen.dart';
import 'package:ambarket_mobile/features/order/domain/models/order_model.dart';
import 'package:ambarket_mobile/features/order/presentation/providers/order_provider.dart';

void main() {
  testWidgets('InvoiceScreen renders invoice number', (WidgetTester tester) async {
    final mockDate = DateTime(2026, 1, 1);
    final mockOrder = OrderModel(
      id: 'ORDER_UUID',
      productId: 'p1',
      buyerId: 'b1',
      sellerId: 's1',
      totalPrice: 150000,
      subtotal: 150000,
      shippingAddress: 'Address',
      receiverPhone: '0800',
      status: 'paid',
      paymentMethod: 'bca',
      paymentStatus: 'paid',
      createdAt: mockDate,
      updatedAt: mockDate,
      invoiceNumber: 'INV/2026/01/01/TEST',
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
          home: InvoiceScreen(orderId: 'ORDER_UUID'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Invoice'), findsOneWidget);
    expect(find.textContaining('INV/20260101/ORDER_UU'), findsOneWidget);
  });
}
