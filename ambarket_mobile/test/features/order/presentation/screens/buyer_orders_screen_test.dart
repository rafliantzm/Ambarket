import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/order/presentation/screens/buyer_orders_screen.dart';
import 'package:ambarket_mobile/features/order/presentation/providers/order_provider.dart';
import 'package:ambarket_mobile/features/order/domain/models/order_model.dart';
import 'package:ambarket_mobile/features/marketplace/domain/models/product_model.dart';
import 'package:ambarket_mobile/features/profile/domain/models/profile_model.dart';

void main() {
  testWidgets('BuyerOrdersScreen renders actions based on status', (WidgetTester tester) async {
    final mockProduct = ProductModel(
      id: 'p1',
      sellerId: 's1',
      categoryId: 'c1',
      title: 'Item',
      description: 'Desc',
      price: 100,
      condition: 'good',
      location: 'Jakarta',
      isNegotiable: true,
      status: 'active',
      createdAt: DateTime.now(),
      images: [],
    );
    final mockBuyer = ProfileModel(id: 'b1', name: 'Buyer', role: 'user', createdAt: DateTime.now());
    final mockSeller = ProfileModel(id: 's1', name: 'Seller', role: 'user', createdAt: DateTime.now());

    final mockOrders = [
      OrderModel(
        id: 'order_1_uuid_string',
        productId: 'p1',
        buyerId: 'b1',
        sellerId: 's1',
        totalPrice: 100,
        shippingAddress: 'Address',
        shippingPhone: '0800',
        status: 'pending_payment',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        product: mockProduct,
        buyer: mockBuyer,
        seller: mockSeller,
      ),
      OrderModel(
        id: 'order_2_uuid_string',
        productId: 'p1',
        buyerId: 'b1',
        sellerId: 's1',
        totalPrice: 100,
        shippingAddress: 'Address',
        shippingPhone: '0800',
        status: 'shipped',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        product: mockProduct,
        buyer: mockBuyer,
        seller: mockSeller,
      ),
    ];

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          buyerOrdersProvider.overrideWith((ref) => mockOrders),
        ],
        child: const MaterialApp(
          home: BuyerOrdersScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    
    // Debug print
    // final texts = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).toList();
    // print('Rendered texts: $texts');

    expect(find.text('Pesanan Saya'), findsOneWidget);
    
    // Status text
    expect(find.text('Belum Dibayar'), findsOneWidget);
    expect(find.text('Dikirim'), findsOneWidget);
    
    // Actions for pending_payment (Buyer)
    expect(find.text('Batalkan'), findsOneWidget);
    expect(find.text('Simulasi Bayar'), findsOneWidget);
    
    // Actions for shipped (Buyer)
    expect(find.text('Pesanan Diterima'), findsOneWidget);
    
    // Dialog check
    await tester.tap(find.text('Simulasi Bayar'));
    await tester.pumpAndSettle();
    expect(find.text('Simulasi Pembayaran'), findsOneWidget);
    
    // Cancel dialog
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
  });
}
